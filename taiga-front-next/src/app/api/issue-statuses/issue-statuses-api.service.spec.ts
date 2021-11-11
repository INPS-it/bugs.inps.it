/**
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright (c) 2021-present Kaleidos Ventures SL
 */

import { createHttpFactory, SpectatorHttp, HttpMethod } from '@ngneat/spectator';

import { ConfigService } from '@/app/config.service';
import { ConfigServiceMock } from '@/app/config.service.mock';
import { IssueStatusesApiService } from './issue-statuses-api.service';
import { IssueStatusMockFactory } from './issue-statuses.model.mock';
import { parseQueryParams } from '@/utils/test.helpers';

describe('IssueStatusesApiService', () => {

  let spectator: SpectatorHttp<IssueStatusesApiService>;
  const createHttp = createHttpFactory({
    service: IssueStatusesApiService,
    providers: [
      { provide: ConfigService, useValue: ConfigServiceMock },
    ],
  });

  beforeEach(() => spectator = createHttp());

  it('list', () => {
    spectator.service.list().subscribe();
    spectator.expectOne(`${ConfigServiceMock.apiUrl}/issue-statuses`, HttpMethod.GET);
  });

  it('list filtered by project', () => {
    const project = 1;
    const queryParams = {
      project: project.toString(),
    };

    spectator.service.list(project).subscribe();
    spectator.expectOne(`${ConfigServiceMock.apiUrl}/issue-statuses?${parseQueryParams(queryParams)}`, HttpMethod.GET);
  });

  it('get', () => {
    const id = 1;

    spectator.service.get(id).subscribe();
    spectator.expectOne(`${ConfigServiceMock.apiUrl}/issue-statuses/${id}`, HttpMethod.GET);
  });

  it('create', () => {
    const data = {
      name: 'test',
      color: '#fabada',
      order: 1,
      isClosed: false,
      project: 1,
    };

    spectator.service.create(data).subscribe();
    const req = spectator.expectOne(`${ConfigServiceMock.apiUrl}/issue-statuses`, HttpMethod.POST);
    expect(req.request.body).toEqual(data);
  });

  it('put', () => {
    const id = 1;
    const data = IssueStatusMockFactory.build({id});

    spectator.service.put(id, data).subscribe();
    const req = spectator.expectOne(`${ConfigServiceMock.apiUrl}/issue-statuses/${id}`, HttpMethod.PUT);
    expect(req.request.body).toEqual(data);
  });

  it('patch', () => {
    const id = 1;
    const data = {
      color: '#fabada',
    };

    spectator.service.patch(id, data).subscribe();
    const req = spectator.expectOne(`${ConfigServiceMock.apiUrl}/issue-statuses/${id}`, HttpMethod.PATCH);
    expect(req.request.body).toEqual(data);
  });

  it('delete', () => {
    const id = 1;

    spectator.service.delete(id).subscribe();
    spectator.expectOne(`${ConfigServiceMock.apiUrl}/issue-statuses/${id}`, HttpMethod.DELETE);
  });

  it('update order in bulk', () => {
    const project = 1;
    const newOrder = [
      [1, 0],
      [2, 2],
      [3, 1],
    ];

    spectator.service.updateOrderInBulk(project, newOrder).subscribe();
    const req = spectator.expectOne(
      `${ConfigServiceMock.apiUrl}/issue-statuses/bulk_update_order`,
       HttpMethod.POST);
    expect(req.request.body).toEqual({bulkIssueStatuses: newOrder, project});
  });
});
