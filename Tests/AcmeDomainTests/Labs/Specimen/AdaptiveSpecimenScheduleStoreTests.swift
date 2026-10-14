@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAdaptiveSpecimenScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AdaptiveSpecimenScheduleStore = Labs.newMemoryAdaptiveSpecimenScheduleStore()
        let item = Labs.newAdaptiveSpecimenSchedule("code-204", name: "name-491")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
