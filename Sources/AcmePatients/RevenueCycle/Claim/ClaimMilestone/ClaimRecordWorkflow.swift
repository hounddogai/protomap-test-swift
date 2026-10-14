import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves claim records through their life cycle and keeps a journal of what it did.
    final class ClaimRecordDesk {
        var store: any ClaimRecordStore
        var validator: ClaimRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClaimRecordEngine

        init(store: any ClaimRecordStore, validator: ClaimRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClaimRecordEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClaimRecordStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClaimRecordStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim record \(code) not found")
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
                if item.startsAt > cutoff {
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

    static func newClaimRecordDesk(_ store: any ClaimRecordStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ClaimRecordDesk {
        return ClaimRecordDesk(
            store: store,
            validator: defaultClaimRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultClaimRecordEngine(flags)
        )
    }
}
