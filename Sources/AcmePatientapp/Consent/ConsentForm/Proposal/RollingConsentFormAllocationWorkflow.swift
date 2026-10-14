import AcmePlatform
import Foundation

extension Consent {
    /// Moves rolling consent form allocations through their life cycle and keeps a journal of what it did.
    final class RollingConsentFormAllocationDesk {
        var store: any RollingConsentFormAllocationStore
        var validator: RollingConsentFormAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingConsentFormAllocationEngine

        init(store: any RollingConsentFormAllocationStore, validator: RollingConsentFormAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingConsentFormAllocationEngine) {
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
                throw Kit.Failure("rolling consent form allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingConsentFormAllocationStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling consent form allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingConsentFormAllocationStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling consent form allocation \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.updatedAt > cutoff {
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

    static func newRollingConsentFormAllocationDesk(_ store: any RollingConsentFormAllocationStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingConsentFormAllocationDesk {
        return RollingConsentFormAllocationDesk(
            store: store,
            validator: defaultRollingConsentFormAllocationValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingConsentFormAllocationEngine(flags)
        )
    }
}
