@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingProxyScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newPendingProxySchedule("code-372", title: "title-328")
        let view = Consent.toPendingProxyScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toPendingProxyScheduleViews([item, item]).count == 2)
    }
}
