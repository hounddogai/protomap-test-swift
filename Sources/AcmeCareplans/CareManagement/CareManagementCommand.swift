import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the area's jobs against sample data, as operators do from the command line.
    enum Command {
        static func run() {
            let clock: any Kit.Clocks.Clock = Kit.Clocks.system()
            let commands: [String: () -> Bool] = [
                "outreach-cycle": { () -> Bool in
                    let store: any OutreachCycleStore = newMemoryOutreachCycleStore()
                    for index in 0..<7 {
                        store.save(newOutreachCycle("outreach-cycle-\(index)", name: "Sample outreach cycle \(index)"))
                    }
                    let flow = newOutreachCycleDesk(store, clock: clock, flags: Kit.Flags.newRegistry())
                    do {
                        try flow.submit("outreach-cycle-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildOutreachCycleReport("Outreach Cycle", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.audit(Int(Date().timeIntervalSince1970)) >= 0
                },
                "program-draft": { () -> Bool in
                    let store: any ProgramDraftStore = newMemoryProgramDraftStore()
                    for index in 0..<7 {
                        store.save(newProgramDraft("program-draft-\(index)", title: "Sample program draft \(index)"))
                    }
                    let flow = newProgramDraftManager(store, clock: clock)
                    do {
                        try flow.openValue("program-draft-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildProgramDraftReport("Program Draft", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.reviewStale(Int(Date().timeIntervalSince1970)) >= 0
                },
            ]
            var failed = 0
            for (name, command) in commands.sorted(by: { $0.key < $1.key }) {
                if !command() {
                    Swift.print("\(name) failed")
                    failed += 1
                }
            }
            if failed > 0 {
                Foundation.exit(Int32(1))
            }
        }
    }
}
