@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryScheduledProgramProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ScheduledProgramProfileStore = CareManagement.newMemoryScheduledProgramProfileStore()
        let item = CareManagement.newScheduledProgramProfile("code-15", title: "title-468")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
