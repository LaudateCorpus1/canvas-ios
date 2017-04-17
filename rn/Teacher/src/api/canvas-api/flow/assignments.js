// @flow

export type AssignmentGroup = {
  id: string,
  name: string,
  position: number,
  group_weight: number,
  sis_source_id: string,
  integration_data: any,
  assignments: Assignment[],
  rules?: any,
}

export type Assignment = {
  id: string,
  name: string,
  description: ?string,
  created_at: string,
  updated_at: string,
  due_at: ?string,
  lock_at?: ?string,
  unlock_at?: ?string,
  all_dates?: AssignmentDate[],
  has_overrides: boolean,
  overrides?: AssignmentOverride[],
  course_id: string,
  published: true,
  unpublishable: false,
  only_visible_to_overrides: boolean,
  points_possible: number,
  needs_grading_count: number,
  submission_types: string[],
  html_url: string,
  position: number,
}

export type AssignmentDate = {
  // (Optional, missing if 'base' is present) id of the assignment override this date
  id?: string,
  // (Optional, present if 'id' is missing) whether this date represents the
  base?: boolean,
  title: string,
  due_at: string,
  unlock_at: string,
  lock_at: string,
}

export type AssignmentOverride = {
  id: string,
  assignment_id: string,
  student_ids: string[],
  group_id: string,
  course_section_id: string,
  title: string,
  due_at: string,
  all_day: boolean,
  all_date_date: string,
  unlock_at: string,
  lock_at: string,
}
