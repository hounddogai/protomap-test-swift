@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenScheduleStore = Labs.newMemorySpecimenScheduleStore()
        let item = Labs.newSpecimenSchedule("code-388", title: "title-320")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
