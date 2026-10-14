@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolScoreStore = Staffing.newMemoryFloatPoolScoreStore()
        let item = Staffing.newFloatPoolScore("code-821", label: "label-595")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
