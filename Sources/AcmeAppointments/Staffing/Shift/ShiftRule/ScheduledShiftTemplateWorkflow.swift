import AcmePlatform
import Foundation

extension Staffing {
    /// Moves scheduled shift templates through their life cycle and keeps a journal of what it did.
    final class ScheduledShiftTemplateService {
        var store: any ScheduledShiftTemplateStore
        var validator: ScheduledShiftTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledShiftTemplateEngine

        init(store: any ScheduledShiftTemplateStore, validator: ScheduledShiftTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledShiftTemplateEngine) {
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
                throw Kit.Failure("scheduled shift template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledShiftTemplateStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled shift template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledShiftTemplateStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled shift template \(code) not found")
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

    static func newScheduledShiftTemplateService(_ store: any ScheduledShiftTemplateStore, clock: any Kit.Clocks.Clock) -> ScheduledShiftTemplateService {
        return ScheduledShiftTemplateService(
            store: store,
            validator: defaultScheduledShiftTemplateValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledShiftTemplateEngine()
        )
    }
}
