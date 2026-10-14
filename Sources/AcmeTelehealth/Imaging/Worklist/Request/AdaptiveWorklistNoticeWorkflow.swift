import AcmePlatform
import Foundation

extension Imaging {
    /// Moves adaptive worklist notices through their life cycle and keeps a journal of what it did.
    final class AdaptiveWorklistNoticeService {
        var store: any AdaptiveWorklistNoticeStore
        var validator: AdaptiveWorklistNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AdaptiveWorklistNoticeEngine

        init(store: any AdaptiveWorklistNoticeStore, validator: AdaptiveWorklistNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AdaptiveWorklistNoticeEngine) {
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
                throw Kit.Failure("adaptive worklist notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AdaptiveWorklistNoticeStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive worklist notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AdaptiveWorklistNoticeStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("adaptive worklist notice \(code) not found")
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

    static func newAdaptiveWorklistNoticeService(_ store: any AdaptiveWorklistNoticeStore, clock: any Kit.Clocks.Clock) -> AdaptiveWorklistNoticeService {
        return AdaptiveWorklistNoticeService(
            store: store,
            validator: defaultAdaptiveWorklistNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultAdaptiveWorklistNoticeEngine()
        )
    }
}
