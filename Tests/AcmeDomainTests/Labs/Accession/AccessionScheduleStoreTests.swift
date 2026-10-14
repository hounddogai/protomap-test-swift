@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionScheduleStore = Labs.newMemoryAccessionScheduleStore()
        let item = Labs.newAccessionSchedule("code-495", title: "title-883")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
