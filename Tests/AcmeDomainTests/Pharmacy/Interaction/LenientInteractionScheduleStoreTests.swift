@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLenientInteractionScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LenientInteractionScheduleStore = Pharmacy.newMemoryLenientInteractionScheduleStore()
        let item = Pharmacy.newLenientInteractionSchedule("code-388", title: "title-181")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
