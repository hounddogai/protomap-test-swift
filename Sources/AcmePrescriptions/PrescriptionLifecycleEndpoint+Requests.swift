import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging
import SwiftProtobuf

extension Acme_Prescriptions_V1_ResolvePrescriptionsRequest {
    static func forPrescriptionLifecycleEndpointRenewPrescription0(
        _ input: Acme_Prescriptions_V1_RenewPrescriptionRequest
    ) -> Self {
        Acme_Prescriptions_V1_ResolvePrescriptionsRequest.with {
            $0.context = input.context
        }
    }
}
