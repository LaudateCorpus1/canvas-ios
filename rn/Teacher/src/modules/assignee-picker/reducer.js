// @flow

import { Reducer } from 'redux'
import Actions from './actions'
import { handleActions } from 'redux-actions'
import handleAsync from '../../utils/handleAsync'
import fromPairs from 'lodash/fromPairs'

const { refreshSections } = Actions

export const sections: Reducer<any, any> = handleActions({
  [refreshSections.toString()]: handleAsync({
    resolved: (state, { result }) => {
      const incoming = fromPairs(result.data
        .map(section => [section.id, section]))
      return { ...state, ...incoming }
    },
  }),
}, {})
