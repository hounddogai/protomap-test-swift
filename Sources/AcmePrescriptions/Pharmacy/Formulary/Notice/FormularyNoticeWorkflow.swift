import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves formulary notices through their life cycle and keeps a journal of what it did.
    final class FormularyNoticeWorkflow {
        var store: any FormularyNoticeStore
        var validator: FormularyNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FormularyNoticeEngine

        init(store: any FormularyNoticeStore, validator: FormularyNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FormularyNoticeEngine) {
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
                throw Kit.Failure("formulary notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FormularyNoticeStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FormularyNoticeStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary notice \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newFormularyNoticeWorkflow(_ store: any FormularyNoticeStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FormularyNoticeWorkflow {
        return FormularyNoticeWorkflow(
            store: store,
            validator: defaultFormularyNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultFormularyNoticeEngine(flags)
        )
    }
}
