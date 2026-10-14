@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryStrictShiftScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.StrictShiftScoreStore = Staffing.newMemoryStrictShiftScoreStore()
        let item = Staffing.newStrictShiftScore("code-633", title: "title-645")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
