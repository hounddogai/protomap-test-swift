import AcmePlatform
import Foundation

extension Staffing {
    /// Moves rolling overtime drafts through their life cycle and keeps a journal of what it did.
    final class RollingOvertimeDraftManager {
        var store: any RollingOvertimeDraftStore
        var validator: RollingOvertimeDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingOvertimeDraftEngine

        init(store: any RollingOvertimeDraftStore, validator: RollingOvertimeDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingOvertimeDraftEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling overtime draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingOvertimeDraftStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling overtime draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingOvertimeDraftStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling overtime draft \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newRollingOvertimeDraftManager(_ store: any RollingOvertimeDraftStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingOvertimeDraftManager {
        return RollingOvertimeDraftManager(
            store: store,
            validator: defaultRollingOvertimeDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingOvertimeDraftEngine(flags)
        )
    }
}
