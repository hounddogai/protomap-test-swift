@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackSubstitutionProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newFallbackSubstitutionProposal("code-692", label: "label-158")
        let view = Pharmacy.toFallbackSubstitutionProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toFallbackSubstitutionProposalViews([item, item]).count == 2)
    }
}
