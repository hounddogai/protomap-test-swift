@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedSubstitutionProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newWeightedSubstitutionProposal("code-895", title: "title-940")
        let view = Pharmacy.toWeightedSubstitutionProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toWeightedSubstitutionProposalViews([item, item]).count == 2)
    }
}
