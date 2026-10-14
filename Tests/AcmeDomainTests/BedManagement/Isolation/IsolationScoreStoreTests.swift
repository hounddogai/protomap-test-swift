@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryIsolationScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.IsolationScoreStore = BedManagement.newMemoryIsolationScoreStore()
        let item = BedManagement.newIsolationScore("code-341", title: "title-722")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
