@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveDispenseProposalViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newAdaptiveDispenseProposal("code-125", title: "title-66")
        let view = Pharmacy.toAdaptiveDispenseProposalView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toAdaptiveDispenseProposalViews([item, item]).count == 2)
    }
}
