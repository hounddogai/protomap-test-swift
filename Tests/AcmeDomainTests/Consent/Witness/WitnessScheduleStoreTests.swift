@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessScheduleStore = Consent.newMemoryWitnessScheduleStore()
        let item = Consent.newWitnessSchedule("code-543", title: "title-193")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
