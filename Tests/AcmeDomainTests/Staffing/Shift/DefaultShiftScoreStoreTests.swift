@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryDefaultShiftScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.DefaultShiftScoreStore = Staffing.newMemoryDefaultShiftScoreStore()
        let item = Staffing.newDefaultShiftScore("code-828", name: "name-838")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
