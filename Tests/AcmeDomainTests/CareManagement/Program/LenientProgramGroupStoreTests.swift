@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLenientProgramGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LenientProgramGroupStore = CareManagement.newMemoryLenientProgramGroupStore()
        let item = CareManagement.newLenientProgramGroup("code-285", label: "label-405")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
