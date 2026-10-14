@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularyScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularyScheduleStore = Pharmacy.newMemoryFormularyScheduleStore()
        let item = Pharmacy.newFormularySchedule("code-880", name: "name-493")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
