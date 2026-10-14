import AcmePlatform
import Foundation

extension Staffing {
    /// Moves float pool notices through their life cycle and keeps a journal of what it did.
    final class FloatPoolNoticeWorkflow {
        var store: any FloatPoolNoticeStore
        var validator: FloatPoolNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FloatPoolNoticeEngine

        init(store: any FloatPoolNoticeStore, validator: FloatPoolNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FloatPoolNoticeEngine) {
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
                throw Kit.Failure("float pool notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FloatPoolNoticeStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FloatPoolNoticeStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("float pool notice \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newFloatPoolNoticeWorkflow(_ store: any FloatPoolNoticeStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> FloatPoolNoticeWorkflow {
        return FloatPoolNoticeWorkflow(
            store: store,
            validator: defaultFloatPoolNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultFloatPoolNoticeEngine(flags)
        )
    }
}
