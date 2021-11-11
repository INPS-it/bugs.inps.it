/**
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright (c) 2021-present Kaleidos Ventures SL
 */

import * as webpack from 'webpack';

export default function(config: webpack.Configuration) {
  if (config.module) {
    config.module.rules.push(
      {
        test   : /\.css$/,
        loader : 'postcss-loader',
      }
    );
  }

  return config;
}
