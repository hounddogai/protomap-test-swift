import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves dispense audits through their life cycle and keeps a journal of what it did.
    final class DispenseAuditDesk {
        var store: any DispenseAuditStore
        var validator: DispenseAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DispenseAuditEngine

        init(store: any DispenseAuditStore, validator: DispenseAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DispenseAuditEngine) {
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
                throw Kit.Failure("dispense audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DispenseAuditStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DispenseAuditStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense audit \(code) not found")
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

    static func newDispenseAuditDesk(_ store: any DispenseAuditStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DispenseAuditDesk {
        return DispenseAuditDesk(
            store: store,
            validator: defaultDispenseAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultDispenseAuditEngine(flags)
        )
    }
}
