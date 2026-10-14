@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Imaging.newWorklistLedger("code-939", name: "name-12")
        let view = Imaging.toWorklistLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Imaging.toWorklistLedgerViews([item, item]).count == 2)
    }
}
