import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves scheduled authorization snapshots through their life cycle and keeps a journal of what it did.
    final class ScheduledAuthorizationSnapshotService {
        var store: any ScheduledAuthorizationSnapshotStore
        var validator: ScheduledAuthorizationSnapshotValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledAuthorizationSnapshotEngine

        init(store: any ScheduledAuthorizationSnapshotStore, validator: ScheduledAuthorizationSnapshotValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledAuthorizationSnapshotEngine) {
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
                throw Kit.Failure("scheduled authorization snapshot \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledAuthorizationSnapshotStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled authorization snapshot \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledAuthorizationSnapshotStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled authorization snapshot \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newScheduledAuthorizationSnapshotService(_ store: any ScheduledAuthorizationSnapshotStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledAuthorizationSnapshotService {
        return ScheduledAuthorizationSnapshotService(
            store: store,
            validator: defaultScheduledAuthorizationSnapshotValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledAuthorizationSnapshotEngine(flags)
        )
    }
}
