@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDenialRecord("code-471", name: "name-631")
        let view = RevenueCycle.toDenialRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDenialRecordViews([item, item]).count == 2)
    }
}
