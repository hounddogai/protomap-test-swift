import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rounding templates through their life cycle and keeps a journal of what it did.
    final class RoundingTemplateService {
        var store: any RoundingTemplateStore
        var validator: RoundingTemplateValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RoundingTemplateStore, validator: RoundingTemplateValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding template \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RoundingTemplateStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding template \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RoundingTemplateStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newRoundingTemplateService(_ store: any RoundingTemplateStore, clock: any Kit.Clocks.Clock) -> RoundingTemplateService {
        return RoundingTemplateService(
            store: store,
            validator: defaultRoundingTemplateValidator(),
            clock: clock,
            journal: []
        )
    }
}
