import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Featureflags_V1_CreateFeatureFlagRequest {
    static func forMedicalRecordApprovalEndpointCommentMedicalRecordApproval1(
        _ input: Acme_Patients_V1_CommentMedicalRecordApprovalRequest
    ) -> Self {
        Acme_Featureflags_V1_CreateFeatureFlagRequest.with {
            $0.context = input.context
            $0.featureFlag = Acme_Featureflags_V1_FeatureFlag.with {
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdAt = input.medicalRecord.audit.createdAt
                    $0.updatedAt = input.medicalRecord.audit.updatedAt
                }
            }
        }
    }
}
