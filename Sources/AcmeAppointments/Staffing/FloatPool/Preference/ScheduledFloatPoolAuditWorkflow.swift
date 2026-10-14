import AcmePlatform
import Foundation

extension Staffing {
    /// Moves scheduled float pool audits through their life cycle and keeps a journal of what it did.
    final class ScheduledFloatPoolAuditManager {
        var store: any ScheduledFloatPoolAuditStore
        var validator: ScheduledFloatPoolAuditValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledFloatPoolAuditEngine

        init(store: any ScheduledFloatPoolAuditStore, validator: ScheduledFloatPoolAuditValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledFloatPoolAuditEngine) {
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
                throw Kit.Failure("scheduled float pool audit \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledFloatPoolAuditStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled float pool audit \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledFloatPoolAuditStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled float pool audit \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newScheduledFloatPoolAuditManager(_ store: any ScheduledFloatPoolAuditStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ScheduledFloatPoolAuditManager {
        return ScheduledFloatPoolAuditManager(
            store: store,
            validator: defaultScheduledFloatPoolAuditValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledFloatPoolAuditEngine(flags)
        )
    }
}
