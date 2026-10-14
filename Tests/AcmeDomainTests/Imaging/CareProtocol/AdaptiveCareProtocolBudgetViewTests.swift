@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptiveCareProtocolBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newAdaptiveCareProtocolBudget("code-804", label: "label-604")
        let view = Imaging.toAdaptiveCareProtocolBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toAdaptiveCareProtocolBudgetViews([item, item]).count == 2)
    }
}
