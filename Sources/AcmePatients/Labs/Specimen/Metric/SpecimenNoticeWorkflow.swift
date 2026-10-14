import AcmePlatform
import Foundation

extension Labs {
    /// Moves specimen notices through their life cycle and keeps a journal of what it did.
    final class SpecimenNoticeWorkflow {
        var store: any SpecimenNoticeStore
        var validator: SpecimenNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SpecimenNoticeEngine

        init(store: any SpecimenNoticeStore, validator: SpecimenNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SpecimenNoticeEngine) {
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
                throw Kit.Failure("specimen notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SpecimenNoticeStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SpecimenNoticeStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen notice \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newSpecimenNoticeWorkflow(_ store: any SpecimenNoticeStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SpecimenNoticeWorkflow {
        return SpecimenNoticeWorkflow(
            store: store,
            validator: defaultSpecimenNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultSpecimenNoticeEngine(flags)
        )
    }
}
