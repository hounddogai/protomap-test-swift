@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDefaultInteractionScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DefaultInteractionScheduleStore = Pharmacy.newMemoryDefaultInteractionScheduleStore()
        let item = Pharmacy.newDefaultInteractionSchedule("code-675", label: "label-433")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
