import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Telehealth_V1_QuoteTriageRequest {
    static func forTriageValidationEndpointNormalizeTriage1(
        _ input: Acme_Telehealth_V1_NormalizeTriageRequest,
        reply0: Acme_Telehealth_V1_RecalculateTriagesResponse
    ) -> Self {
        Acme_Telehealth_V1_QuoteTriageRequest.with {
            $0.context = input.context
            $0.triage = Acme_Telehealth_V1_Triage.with {
                $0.assignee = Acme_Identity_V1_UserRef.with {
                    $0.displayName = input.triage.assignee.displayName
                }
                $0.audit = Acme_Common_V1_AuditInfo.with {
                    $0.createdBy = reply0.triage.audit.createdBy
                    $0.updatedAt = reply0.triage.audit.updatedAt
                    $0.updatedBy = input.triage.audit.updatedBy
                }
            }
        }
    }
}
