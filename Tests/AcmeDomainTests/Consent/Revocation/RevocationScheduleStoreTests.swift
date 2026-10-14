@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationScheduleStore = Consent.newMemoryRevocationScheduleStore()
        let item = Consent.newRevocationSchedule("code-947", name: "name-200")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
