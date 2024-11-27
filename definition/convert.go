package definition

import (
	"database/sql"

	"google.golang.org/protobuf/types/known/timestamppb"
)

func ProtoTimeToSql(protoTime *timestamppb.Timestamp) sql.NullTime {
	sqlTime := sql.NullTime{}
	if protoTime != nil {
		sqlTime.Scan(protoTime.AsTime())
	}
	return sqlTime
}

func SQLTimeToProto(sqlTime sql.NullTime) *timestamppb.Timestamp {
	if sqlTime.Valid {
		return timestamppb.New(sqlTime.Time)
	}
	return nil
}
