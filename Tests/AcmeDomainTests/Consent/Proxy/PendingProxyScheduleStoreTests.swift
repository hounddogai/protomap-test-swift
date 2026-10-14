@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPendingProxyScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PendingProxyScheduleStore = Consent.newMemoryPendingProxyScheduleStore()
        let item = Consent.newPendingProxySchedule("code-372", title: "title-328")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
