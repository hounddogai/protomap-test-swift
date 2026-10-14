@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryManualProxyScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ManualProxyScheduleStore = Consent.newMemoryManualProxyScheduleStore()
        let item = Consent.newManualProxySchedule("code-771", title: "title-115")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
