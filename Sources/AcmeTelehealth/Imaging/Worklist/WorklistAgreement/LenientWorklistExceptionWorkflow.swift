import AcmePlatform
import Foundation

extension Imaging {
    /// Moves lenient worklist exceptions through their life cycle and keeps a journal of what it did.
    final class LenientWorklistExceptionWorkflow {
        var store: any LenientWorklistExceptionStore
        var validator: LenientWorklistExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientWorklistExceptionEngine

        init(store: any LenientWorklistExceptionStore, validator: LenientWorklistExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientWorklistExceptionEngine) {
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
                throw Kit.Failure("lenient worklist exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientWorklistExceptionStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient worklist exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientWorklistExceptionStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient worklist exception \(code) not found")
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

    static func newLenientWorklistExceptionWorkflow(_ store: any LenientWorklistExceptionStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientWorklistExceptionWorkflow {
        return LenientWorklistExceptionWorkflow(
            store: store,
            validator: defaultLenientWorklistExceptionValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientWorklistExceptionEngine(flags)
        )
    }
}
