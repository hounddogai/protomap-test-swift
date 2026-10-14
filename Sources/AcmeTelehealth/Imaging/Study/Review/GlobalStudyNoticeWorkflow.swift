import AcmePlatform
import Foundation

extension Imaging {
    /// Moves global study notices through their life cycle and keeps a journal of what it did.
    final class GlobalStudyNoticeCoordinator {
        var store: any GlobalStudyNoticeStore
        var validator: GlobalStudyNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalStudyNoticeEngine

        init(store: any GlobalStudyNoticeStore, validator: GlobalStudyNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalStudyNoticeEngine) {
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
                throw Kit.Failure("global study notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalStudyNoticeStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global study notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalStudyNoticeStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global study notice \(code) not found")
            }
            let result = engine.evaluate(item)
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

    static func newGlobalStudyNoticeCoordinator(_ store: any GlobalStudyNoticeStore, clock: any Kit.Clocks.Clock) -> GlobalStudyNoticeCoordinator {
        return GlobalStudyNoticeCoordinator(
            store: store,
            validator: defaultGlobalStudyNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalStudyNoticeEngine()
        )
    }
}
