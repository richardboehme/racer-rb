Racer::Trace =
  Data.define(
    :method_owner,
    :method_owner_type,
    :method_name,
    :return_type,
    :params
  )

Racer::Trace::Param =
  Data.define(
    :name,
    :class_name,
    :type
  )

Racer::Trace::Param::TYPES = [
  :required,
  :optional,
  :rest,
  :keyword_required,
  :keyword_optional,
  :keyword_rest,
  :block
].freeze
