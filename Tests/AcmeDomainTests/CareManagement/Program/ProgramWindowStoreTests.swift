@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramWindowStore = CareManagement.newMemoryProgramWindowStore()
        let item = CareManagement.newProgramWindow("code-51", name: "name-143")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
