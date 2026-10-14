import AcmePlatform
import Foundation

extension Staffing {
    /// Moves rolling credential allocations through their life cycle and keeps a journal of what it did.
    final class RollingCredentialAllocationManager {
        var store: any RollingCredentialAllocationStore
        var validator: RollingCredentialAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingCredentialAllocationEngine

        init(store: any RollingCredentialAllocationStore, validator: RollingCredentialAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingCredentialAllocationEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling credential allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingCredentialAllocationStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling credential allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingCredentialAllocationStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling credential allocation \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newRollingCredentialAllocationManager(_ store: any RollingCredentialAllocationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingCredentialAllocationManager {
        return RollingCredentialAllocationManager(
            store: store,
            validator: defaultRollingCredentialAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingCredentialAllocationEngine(flags)
        )
    }
}
