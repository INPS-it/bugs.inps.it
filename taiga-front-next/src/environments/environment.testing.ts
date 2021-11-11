/**
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright (c) 2021-present Kaleidos Ventures SL
 */

import { Environment } from './environment.model';

export const environment: Environment = {
  production: false,
  configLocal: {
    api: 'https://api.taiga.io/api/v1/',
    defaultLanguage: 'en',
  },
};
