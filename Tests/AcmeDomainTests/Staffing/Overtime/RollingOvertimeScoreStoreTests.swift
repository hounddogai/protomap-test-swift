@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryRollingOvertimeScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.RollingOvertimeScoreStore = Staffing.newMemoryRollingOvertimeScoreStore()
        let item = Staffing.newRollingOvertimeScore("code-249", label: "label-931")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
