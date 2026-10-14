import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves denial thresholds through their life cycle and keeps a journal of what it did.
    final class DenialThresholdDesk {
        var store: any DenialThresholdStore
        var validator: DenialThresholdValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DenialThresholdEngine

        init(store: any DenialThresholdStore, validator: DenialThresholdValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DenialThresholdEngine) {
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
                throw Kit.Failure("denial threshold \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DenialThresholdStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial threshold \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DenialThresholdStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("denial threshold \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newDenialThresholdDesk(_ store: any DenialThresholdStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DenialThresholdDesk {
        return DenialThresholdDesk(
            store: store,
            validator: defaultDenialThresholdValidator(),
            clock: clock,
            journal: [],
            engine: defaultDenialThresholdEngine(flags)
        )
    }
}
