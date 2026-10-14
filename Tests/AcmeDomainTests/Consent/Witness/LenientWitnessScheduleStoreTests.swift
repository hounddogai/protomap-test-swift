@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLenientWitnessScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LenientWitnessScheduleStore = Consent.newMemoryLenientWitnessScheduleStore()
        let item = Consent.newLenientWitnessSchedule("code-886", title: "title-107")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
