import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves lenient formulary drafts through their life cycle and keeps a journal of what it did.
    final class LenientFormularyDraftWorkflow {
        var store: any LenientFormularyDraftStore
        var validator: LenientFormularyDraftValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientFormularyDraftEngine

        init(store: any LenientFormularyDraftStore, validator: LenientFormularyDraftValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientFormularyDraftEngine) {
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
                throw Kit.Failure("lenient formulary draft \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientFormularyDraftStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient formulary draft \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientFormularyDraftStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient formulary draft \(code) not found")
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

    static func newLenientFormularyDraftWorkflow(_ store: any LenientFormularyDraftStore, clock: any Kit.Clocks.Clock) -> LenientFormularyDraftWorkflow {
        return LenientFormularyDraftWorkflow(
            store: store,
            validator: defaultLenientFormularyDraftValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientFormularyDraftEngine()
        )
    }
}
