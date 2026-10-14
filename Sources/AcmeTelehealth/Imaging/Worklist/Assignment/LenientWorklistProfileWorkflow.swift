import AcmePlatform
import Foundation

extension Imaging {
    /// Moves lenient worklist profiles through their life cycle and keeps a journal of what it did.
    final class LenientWorklistProfileDesk {
        var store: any LenientWorklistProfileStore
        var validator: LenientWorklistProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientWorklistProfileEngine

        init(store: any LenientWorklistProfileStore, validator: LenientWorklistProfileValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientWorklistProfileEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient worklist profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientWorklistProfileStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient worklist profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientWorklistProfileStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient worklist profile \(code) not found")
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

    static func newLenientWorklistProfileDesk(_ store: any LenientWorklistProfileStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> LenientWorklistProfileDesk {
        return LenientWorklistProfileDesk(
            store: store,
            validator: defaultLenientWorklistProfileValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientWorklistProfileEngine(flags)
        )
    }
}
