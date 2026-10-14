import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves manual remittance snapshots through their life cycle and keeps a journal of what it did.
    final class ManualRemittanceSnapshotService {
        var store: any ManualRemittanceSnapshotStore
        var validator: ManualRemittanceSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ManualRemittanceSnapshotEngine

        init(store: any ManualRemittanceSnapshotStore, validator: ManualRemittanceSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ManualRemittanceSnapshotEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual remittance snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ManualRemittanceSnapshotStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual remittance snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ManualRemittanceSnapshotStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("manual remittance snapshot \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newManualRemittanceSnapshotService(_ store: any ManualRemittanceSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ManualRemittanceSnapshotService {
        return ManualRemittanceSnapshotService(
            store: store,
            validator: defaultManualRemittanceSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultManualRemittanceSnapshotEngine(flags)
        )
    }
}
