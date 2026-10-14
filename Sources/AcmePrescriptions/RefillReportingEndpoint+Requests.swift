import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Prescriptions_V1_GetRefillImportStatusRequest {
    static func forRefillReportingEndpointGenerateRefillReport1(
        _ input: Acme_Prescriptions_V1_GenerateRefillReportRequest
    ) -> Self {
        Acme_Prescriptions_V1_GetRefillImportStatusRequest.with {
            $0.context = input.context
            $0.refillID = input.refillID
        }
    }
}
